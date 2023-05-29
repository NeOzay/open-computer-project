---@meta filesystem

local filesystem = {}


---Returns whether autorun is currently enabled. If this is true, newly mounted file systems will be checked for a file named autorun[.lua] in their root directory. If such a file exists, it is executed.
---@return boolean
function filesystem.isAutorunEnabled() end

---Sets whether autorun files should be ran on startup.
---@param value boolean
function filesystem.setAutorunEnabled(value) end


---Returns the canonical form of the specified path, i.e. a path containing no “indirections” such as . or ... For example, the paths /tmp/../bin/ls.lua and /bin/./ls.lua are equivalent, and their canonical form is /bin/ls.lua.
---
---Note that this function truncates relative paths to their topmost “known” directory. For example, ../bin/ls.lua becomes bin/ls.lua. It stays a relative path, however - mind the lack of a leading slash.
---@param path string
---@return string
function filesystem.canonical(path,...) end


---Returns a table containing one entry for each canonical segment of the given path.
---@param path string
---@return string[]
function filesystem.segments(path) end

---Concatenates two or more paths. Note that all paths other than the first are treated as relative paths, even if they begin with a slash. The canonical form of the resulting concatenated path is returned, so fs.concat("a", "..") results in an empty string.
---@param pathA string
---@param pathB string
---@param ... string
---@return string
function filesystem.concat(pathA,pathB,...) end


---Returns the path component of a path to a file, i.e. everything before the last slash in the canonical form of the specified path.
---@param path string
---@return string
function filesystem.path(path) end


---Returns the file name component of a path to a file, i.e. everything after the last slash in the canonical form of the specified path.
---@param path string
---@return string
function filesystem.name(path) end


---This is similar to component.proxy, except that the specified string may also be a file system component's label. We check for the label first, if no file system has the specified label we fall back to component.proxy.
---
---Returns the proxy of the specified file system, or nil and an error message if no file system matching the specified filter was found.
---@param filter string
---@return filesystem | nil, string
---@overload fun(filter:string):filesystem
function filesystem.proxy(filter) end


---Mounts a file system at the specified path. The first parameter can be either a file system component's proxy, its address or its label. The second is a path into the global directory tree. Returns true if the file system was successfully mounted, nil and an error message otherwise.
---@param fs table| string
---@param path string
---@return boolean| nil, string
function filesystem.mount(fs,path) end

---Returns an iterator function over all currently mounted file system component's proxies and the paths at which they are mounted. This means the same proxy may appear multiple times, but with different mount paths.
---@return table, string
function filesystem.mounts() end

---Unmounts a file system. The parameter can either be a file system component's proxy or (abbreviated) address, in which case all mount points of this file system will be removed, or a path into the global directory structure, in which case the file system mount containing that directory will be unmounted.
---@param fsOrPath table|string
---@return boolean
function filesystem.umount(fsOrPath) end

---Checks if the object at the specified path is a symlink, if so returns the path to where it links (as of 1.3.3).
---@param path string
---@return boolean
function filesystem.isLink(path) end


---@param target string
---@param linkpath string
---@return boolean,string
function filesystem.link(target,linkpath) end


---Gets the file system component's proxy that contains the specified path. Returns the proxy and mount path, or nil and an error message.
---@param path string
---@return filesystem,string|nil,string
function filesystem.get(path) end


---Checks whether a file or folder exist at the specified path.
---@param path string
---@return boolean
function filesystem.exists(path) end


---Gets the file size of the file at the specified location. Returns 0 if the path points to anything other than a file.
---@param path string
---@return number
function filesystem.size(path) end


---Gets whether the path points to a directory. Returns false if not, either because the path points to a file, or file.exists(path) is false.
---@param path string
---@return boolean
function filesystem.isDirectory(path) end


---Returns the real world unix timestamp of the last time the file at the specified path was modified. For directories this is usually the time of their creation.
---@param path string
---@return number
function filesystem.lastModified(path) end


---Returns an iterator over all elements in the directory at the specified path. Returns nil and an error messages if the path is invalid or some other error occurred.
---
---Note that directories usually are postfixed with a slash, to allow identifying them without an additional call to fs.isDirectory.
---@param path string
---@return fun():string
function filesystem.list(path) end


---Creates a new directory at the specified path. Creates any parent directories that do not exist yet, if necessary. Returns true on success, nil and an error message otherwise.
---@param path string
---@return boolean,string
function filesystem.makeDirectory(path) end


---Deletes a file or folder. If the path specifies a folder, deletes all files and subdirectories in the folder, recursively. Return true on success, nil and an error message otherwise.
---@param path string
---@return boolean,string
function filesystem.remove(path) end


---Renames a file or folder. If the paths point to different file system components this will only work for files, because it actually perform a copy operation, followed by a deletion if the copy succeeds.
---
---Returns true on success, nil and an error message otherwise.
---@param oldPath string
---@param newPath string
---@return boolean,string
function filesystem.rename(oldPath,newPath) end


---Copies a file to the specified location. The target path has to contain the target file name. Does not support folders.
---@param fromPath string
---@param toPath string
---@return boolean,string
function filesystem.copy(fromPath,toPath) end

---Opens a file at the specified path for reading or writing. If mode is not specified it defaults to “r”. Possible modes are: r, rb, w, wb, a and ab.
---
---Returns a file stream (see below) on success, nil and an error message otherwise.
---
---Note that you can only open a limited number of files per file system at the same time. Files will be automatically closed when the garbage collection kicks in, but it is generally a good idea to call close on the file stream when done with the file.
---
---Important*: it is generally recommended to use io.open instead of this function, to get a buffered wrapper for the file stream.
---
---When opening files directly via the file system API you will get a file stream, a table with four functions. These functions are thin wrappers to the file system proxy's callbacks, which also means that read/write operations are not buffered, and can therefore be slow when reading few bytes often. You'll usually want to use io.open instead.
---@param path string
---@param mode string
---@return ocFile?, string?
function filesystem.open(path,mode) end



---@class ocFile
local ocFile = {}

---Closes the file stream, releasing the handle on the underlying file system.
function ocFile:close() end


---Tries to read the specified number of bytes from the file stream. Returns the read string, which may be shorter than the specified number. Returns nil when the end of the stream was reached. Returns nil and an error message if some error occurred.
---@param n number
---@return string,string
function ocFile:read(n) end


---Jumps to the specified position in the file stream, if possible. Only supported by file streams opened in read mode. The first parameter determines the relative location to seek from and can be cur for the current position, set for the beginning of the stream and end for the end of the stream. The second parameter is the offset by which to modify the position. Returns the new position or nil and an error message if some error occurred.
---
---The default value for the second parameter is 0, so f:seek("set") will reset the position to the start of the file, f:seek("cur") will return the current position in the file.
---@param whence string
---@return string,string
---@overload fun(whence:string, offset:number):number|nil, string)
function ocFile:seek(whence) end


---Writes the specified data to the stream. Returns true on success, nil and an error message otherwise.
---@param str string
---@return string,string
function ocFile:write(str) end

---@class filesystem
local disk = {}

---The currently used capacity of the file system, in bytes.
---@return number
function disk.spaceUsed() end

---Opens a new file descriptor and returns its handle.
---@param path string
---@return number
---@overload fun(path:string,mode:"r"):number
function disk.open(path) end

---Seeks in an open file descriptor with the specified handle. Returns the new pointer position.
---@param handle number
---@param whence string
---@param offset number
---@return number
function disk.seek(handle,whence,offset) end

---Creates a directory at the specified absolute path in the file system. Creates parent directories, if necessary.
---@param path string
---@return boolean
function disk.makeDirectory(path) end

---Returns whether an object exists at the specified absolute path in the file system.
---@param path string
---@return boolean
function disk.exists(path)end

---Returns whether the file system is read-only.
---@return boolean
function disk.isReadOnly() end

---Writes the specified data to an open file descriptor with the specified handle.
---@param handle number
---@param value string
---@return boolean
function disk.write(handle,value) end

---The overall capacity of the file system, in bytes.
---@return number
function disk.spaceTotal() end

---Returns whether the object at the specified absolute path in the file system is a directory.
---@param path string
---@return boolean
function disk.isDirectory(path) end

---Renames/moves an object from the first specified absolute path in the file system to the second.
---@param from string
---@param to string
function disk.rename(from, to) end

---Returns a list of names of objects in the directory at the specified absolute path in the file system.
---@param path string
---@return string[]
function disk.list(path) end

---Returns the (real world) timestamp of when the object at the specified absolute path in the file system was modified.
---@param path string
---@return number
function disk.lastModified(path) end

---Get the current label of the file system.
---@return string
function disk.getLabel() end

---Removes the object at the specified absolute path in the file system.
---@param path string
---@return boolean
function disk.remove(path)end

---Closes an open file descriptor with the specified handle.
---@param handle number
function disk.close(handle)end

---Returns the size of the object at the specified absolute path in the file system.
---@param path string
---@return number
function disk.size(path) end

---Reads up to the specified amount of data from an open file descriptor with the specified handle. Returns nil when end of file is reached.
---@param handle number
---@param count number
function disk.read(handle,count) end


---Sets the label of the file system. Returns the new value, which may be truncated.
---@param value string
---@return string
function disk.setLabel(value) end

return filesystem
