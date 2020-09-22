const std = @import("std");

const c = @import("c_types.zig");
const z = @import("z_types.zig");

const s = @import("serialization.zig");

const cc = @cImport({
    @cInclude("coldclear.h");
});

const usb = @import("libusb.zig");

pub const log_level: std.log.Level = .info;

const switch_vendor_id: u16 = 0x057E;
const switch_product_ids: [1]u16 = [1]u16{ 0x3000 };

const ZagHostError = usb.Error || error{
    DeviceListInitializationFailure,
    ActiveDescriptionRetrievalFailure,
    MissingEndpoints,
    DuplicateEndpoints,
};

pub fn main() ZagHostError!void {
    resume (async run());
}

pub fn run() ZagHostError!void {
    const alloc = std.heap.c_allocator;

    const ctx = try usb.init();
    defer usb.deinit(ctx);

    const conn = try init_switch_connections(alloc, ctx);
    defer free_switch_connections(alloc, conn);

    for(conn) |con| {
        var req_frame = async con.read();
        resume &req_frame;
        const req_res: usb.Error!z.ZagRequest = await &req_frame;
        const req = try req_res;
    }
}

const Connection = struct {
    handle: *usb.DeviceHandle,
    endpoint_in: u8,
    endpoint_out: u8,

    pub fn read(self: @This()) usb.Error!z.ZagRequest {
        std.debug.print("hi", .{});
        var read_frame = async usb.read(std.heap.c_allocator, self.handle, self.endpoint_in, 0xFFFFFFFF, 8);
        const data_res: usb.Error![]u8 = await &read_frame;
        const data = try data_res;
        std.debug.print("{X}", .{data});

        unreachable;
    }
};

fn init_switch_connections(alloc: *std.mem.Allocator, ctx: ?*usb.Context) ZagHostError![]Connection {
    var device_array = std.ArrayList(Connection).init(alloc);
    
    const device_list_opt = try usb.init_device_list(ctx);
    if (device_list_opt) |device_list| {
        defer usb.deinit_device_list(device_list, true);

        for (device_list) |device| {
            const descriptor = try usb.get_device_descriptor(device);
            const correct_vendor_id = descriptor.idVendor == switch_vendor_id;
            const correct_product_id = exists_any(u16, switch_product_ids.len, descriptor.idProduct, switch_product_ids);
            if (correct_vendor_id and correct_product_id) {
                var handle_opt = try usb.open_device_handle(device);
                if (handle_opt) |handle| {
                    try usb.set_auto_detach_kernel_driver(handle, true);
                    const new_connection_opt = connect(device, handle) catch |err| {
                        usb.close_device_handle(handle);
                        return err;
                    };
                    if (new_connection_opt) |new_connection| {
                        try device_array.append(new_connection);
                    } else {
                        std.log.warn("Failed to initialize connection for matching Nintendo Switch device", .{});
                    }
                } else {
                    std.log.warn("Could not open handle for device {X:04} {X:04}", .{ descriptor.idVendor, descriptor.idProduct });
                }
            }
        }
    }

    return device_array.toOwnedSlice();
}

fn free_switch_connections(alloc: *std.mem.Allocator, conns: []Connection) void {
    for (conns) |conn| {
        usb.close_device_handle(conn.handle);
    }
    alloc.free(conns);
}

fn connect(device: *usb.Device, handle: *usb.DeviceHandle) ZagHostError!?Connection {
    try usb.set_device_handle_configuration(handle, 1);

    const descriptor_opt = try usb.get_device_active_config_descriptor(device);
    if (descriptor_opt) |descriptor| {
        const interfaces = descriptor.interface[0..descriptor.bNumInterfaces];

        var endpoint_in: ?u8 = null;
        var endpoint_out: ?u8 = null;

        for (interfaces) |interface| {
            const interface_descriptors = interface.altsetting[0..@intCast(usize, interface.num_altsetting)];

            for (interface_descriptors) |interface_descriptor| {
                const endpoints = interface_descriptor.endpoint[0..interface_descriptor.bNumEndpoints];

                for (endpoints) |endpoint| {
                    const transfer_type = @intToEnum(usb.TransferType, endpoint.bmAttributes & 0b00000011);
                    if (transfer_type == .LIBUSB_TRANSFER_TYPE_BULK) {
                        const direction = @intToEnum(usb.EndpointDirection, endpoint.bEndpointAddress & 0b10000000);

                        switch (direction) {
                            .LIBUSB_ENDPOINT_IN => {
                                if (endpoint_in == null) {
                                    endpoint_in = endpoint.bEndpointAddress;
                                } else {
                                    return ZagHostError.DuplicateEndpoints;
                                }
                            },
                            .LIBUSB_ENDPOINT_OUT => {
                                if (endpoint_out == null) {
                                    endpoint_out = endpoint.bEndpointAddress;
                                } else {
                                    return ZagHostError.DuplicateEndpoints;
                                }
                            },
                            else => unreachable,
                        }
                    }
                }
            }
        }

        if (endpoint_in == null or endpoint_out == null) {
            return ZagHostError.MissingEndpoints;
        } else {
            return Connection{
                .handle = handle,
                .endpoint_in = endpoint_in.?,
                .endpoint_out = endpoint_out.?,
            };
        }
    } else {
        return ZagHostError.ActiveDescriptionRetrievalFailure;
    }
}

fn exists_any(comptime T: type, comptime i: usize, target: T, array: [i]T) bool {
    var found = false;
    var idx: usize = 0;
    while (!found and idx < i) {
        if (std.meta.eql(target, array[idx])) found = true;
        idx += 1;
    }
    return found;
}
