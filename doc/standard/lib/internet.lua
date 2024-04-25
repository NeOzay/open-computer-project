---@meta internet

---@class internetLib
local internet = {}

--- Sends an HTTP request to the specified URL, with the specified POST data, if any.\
--- If no data is specified, a GET request will be made.\
--- The POST data can be in one of two formats: if it's a string, it will be sent as-is.\
--- If it's a table, it will be converted to a string by assuming that each key is the name of a POST variable,\
--- and its associated value is the value for that variable.\
--- method can be explicitly specified to values such as GET, POST, or PUT.\
--- Some examples:\
--- `internet.request(url, {some = "variable", another = 1})` Will send some=variable&another=1.\
--- The returned function is an iterator over chunks of the result, use it like so:\
--- for chunk in internet.request(...) do stuff() end\
--- Note that this method ALSO supports HTTPS. So simply use internet.request("https://example.com") to send a request through HTTPS.\
--- Example specifying PUT: internet.request("https://example.com", "put data", {}, "PUT").\
---@param url string The URL to send the HTTP request to.
---@param data (string|table)? Optional. The data to be sent with the request. It can be a string or a table.
---@param headers table? Optional. Additional headers for the request.
---@param method string? Optional. The HTTP method to be used (GET, POST, PUT, etc.).
---@return handle  @An iterator over chunks of the result.
function internet.request(url, data, headers, method) end

---@class handle
---@operator call:string
local handle = {}

---@return number code, string message, table headers
function handle.response() end

---@class response
---@field code number
---@field message string
---@field headers table

function handle.finishConnect() end

--- Opens a TCP socket using an internet component's connect method and wraps it in a table.\
--- Provides the same methods as a file opened using filesystem.open: read, write, and close.\
--- Note: The seek method will always fail.\
--- It is recommended to use internet.open instead, which will wrap the opened socket in a buffer, the same way io.open wraps files.\
--- The read method on the returned socket is non-blocking. Read will instantly return, but may return an empty string if there is nothing to read.\
--- Write may block until all data has been successfully written. It'll usually return immediately, though.\
---@param address string @The address to connect to.
---@param port number Optional. The port to connect to.
---@return table @The socket table with read, write, and close methods.
function internet.socket(address, port) end

--- Opens a buffered socket stream to the specified address.\
--- The stream can be read from and written from, using s:read and s:write.\
--- In general, it can be treated much like files opened using io.open.\
--- It may often be desirable to set the buffer's read timeout using s:setTimeout(seconds),\
--- to avoid it blocking indefinitely.\
--- The read method on the returned buffer is blocking.\
--- Read will wait until some data is available to be read and return that.\
---@param address string The address to connect to.
---@param port number Optional. The port to connect to.
---@return table @The buffer table with read, write, and close methods.
function internet.open(address, port) end

return internet
