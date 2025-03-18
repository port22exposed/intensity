const std = @import("std");
const zap = @import("zap");

const utility = @import("../../utility.zig");

const allocator = @import("../../main.zig").allocator;

pub fn internal_request(r: zap.Request) !void {
    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/checkUsername")) {
            const username = r.getParamSlice("username") orelse {
                return error.InvalidArguments;
            };

            utility.checkUsername(username) catch |err| {
                switch (err) {
                    error.InvalidCharacters => {
                        r.setStatus(.bad_request);
                        r.sendBody("INVALID_CHARACTERS") catch unreachable;
                    },
                    error.InvalidLength => {
                        r.setStatus(.bad_request);
                        r.sendBody("INVALID_LENGTH") catch unreachable;
                    },
                }
                return;
            };

            r.sendBody("VALIDATED") catch unreachable;
        }
    }
}
