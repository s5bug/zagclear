const std = @import("std");

//TODO
//const usb = @cImport({
//    @cInclude("libusb-1.0/libusb.h");
//});

const usb = @import("libusb-h.zig");

pub const ConfigDescriptor = usb.libusb_config_descriptor;
pub const Context = usb.libusb_context;
pub const Device = usb.libusb_device;
pub const DeviceDescriptor = usb.libusb_device_descriptor;
pub const DeviceHandle = usb.libusb_device_handle;
pub const EndpointDirection = usb.libusb_endpoint_direction;
pub const Transfer = usb.libusb_transfer;
pub const TransferType = usb.libusb_transfer_type;

pub const Error = error{
    IOError,
    InvalidParam,
    AccessDenied,
    NoDevice,
    EntityNotFound,
    ResourceBusy,
    Timeout,
    Overflow,
    PipeError,
    Interrupted,
    OperationNotSupported,
} || std.mem.Allocator.Error;

fn libusb_error_to_zig(err: usb.libusb_error) Error!void {
    return switch (err) {
        .LIBUSB_SUCCESS => {},
        .LIBUSB_ERROR_IO => Error.IOError,
        .LIBUSB_ERROR_INVALID_PARAM => Error.InvalidParam,
        .LIBUSB_ERROR_ACCESS => Error.AccessDenied,
        .LIBUSB_ERROR_NO_DEVICE => Error.NoDevice,
        .LIBUSB_ERROR_NOT_FOUND => Error.EntityNotFound,
        .LIBUSB_ERROR_BUSY => Error.ResourceBusy,
        .LIBUSB_ERROR_TIMEOUT => Error.Timeout,
        .LIBUSB_ERROR_OVERFLOW => Error.Overflow,
        .LIBUSB_ERROR_PIPE => Error.PipeError,
        .LIBUSB_ERROR_INTERRUPTED => Error.Interrupted,
        .LIBUSB_ERROR_NO_MEM => std.mem.Allocator.Error.OutOfMemory,
        .LIBUSB_ERROR_NOT_SUPPORTED => Error.OperationNotSupported,
        else => @panic("Hit LIBUSB_ERROR_OTHER or invalid error. This shouldn't happen!"),
    };
}

pub fn init() Error!?*Context {
    var ctx: ?*Context = null;
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_init(&ctx)));
    return ctx;
}

pub fn deinit(ctx: ?*Context) void {
    usb.libusb_exit(ctx);
}

pub fn init_device_list(ctx: ?*Context) Error!?[]*Device {
    var device_optional_multipointer: ?[*:null]?*Device = null;
    _ = usb.libusb_get_device_list(ctx, &device_optional_multipointer);
    if (device_optional_multipointer) |device_multipointer| {
        const device_span: []?*Device = std.mem.span(device_multipointer);
        const devices: []*Device = @ptrCast([*]*Device, device_span.ptr)[0..device_span.len];
        return devices;
    } else {
        return null;
    }
}

pub fn deinit_device_list(list: []*Device, unref: bool) void {
    const device_multipointer = @ptrCast([*]?*Device, list.ptr);
    usb.libusb_free_device_list(device_multipointer, if (unref) 1 else 0);
}

pub fn get_device_descriptor(device: *Device) Error!DeviceDescriptor {
    var descriptor: DeviceDescriptor = undefined;
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_get_device_descriptor(device, &descriptor)));
    return descriptor;
}

pub fn open_device_handle(device: *Device) Error!?*DeviceHandle {
    var handle: ?*DeviceHandle = null;
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_open(device, &handle)));
    return handle;
}

pub fn close_device_handle(handle: *DeviceHandle) void {
    usb.libusb_close(handle);
}

pub fn set_auto_detach_kernel_driver(handle: *DeviceHandle, enable: bool) Error!void {
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_set_auto_detach_kernel_driver(handle, if (enable) 1 else 0)));
}

pub fn set_device_handle_configuration(handle: *DeviceHandle, configuration: i8) Error!void {
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_set_configuration(handle, configuration)));
}

pub fn get_device_active_config_descriptor(device: *Device) Error!?*ConfigDescriptor {
    var descriptor: ?*ConfigDescriptor = null;
    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_get_active_config_descriptor(device, &descriptor)));
    return descriptor;
}

pub fn init_transfer(packets: u32) *Transfer {
    return usb.libusb_alloc_transfer(@intCast(c_int, packets));
}

pub fn deinit_transfer(transfer: *Transfer) void {
    return usb.libusb_free_transfer(transfer);
}

pub fn read(alloc: *std.mem.Allocator, handle: *DeviceHandle, endpoint: u8, timeout: u32, length: u32) Error![]u8 {
    const slice = try alloc.alloc(u8, length);

    const Impl = struct {
        frame: anyframe,
        actual_length: u32,

        const Self = @This();

        fn callback(transfer_opt: ?*Transfer) callconv(.C) void {
            const transfer = transfer_opt.?;
            const user_data: *Self = @ptrCast(*Self, @alignCast(@alignOf(Self), transfer.user_data));
            const self = user_data;
            self.actual_length = @intCast(u32, transfer.actual_length);
            resume self.frame;
        }
    };

    var impl = Impl {
        .frame = @frame(),
        .actual_length = 0,
    };

    const transfer: *Transfer = init_transfer(0);
    defer deinit_transfer(transfer);

    transfer.dev_handle = handle;
    transfer.endpoint = endpoint;
    transfer.timeout = timeout;
    transfer.length = @intCast(c_int, length);
    transfer.buffer = slice.ptr;

    transfer.callback = Impl.callback;
    transfer.user_data = @ptrCast(*c_void, &impl);

    try libusb_error_to_zig(@intToEnum(usb.libusb_error, usb.libusb_submit_transfer(transfer)));

    suspend;

    const new_length = impl.actual_length;
    
    const new_slice = alloc.shrink(slice, new_length);

    return new_slice[0..new_length];
}
