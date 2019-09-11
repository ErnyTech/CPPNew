module cppnew;

auto CPPNew(T, A...) (auto ref A args) {
    import std.experimental.allocator : make;
    return CPPAllocator.instance.make!T(args);
}

T[] CPPNewArray(T) (size_t length) {
    import std.experimental.allocator : makeArray;
    return CPPAllocator.instance.makeArray!T(length);
}

T[] CPPNewArray(T) (size_t length, T init) {
    import std.experimental.allocator : makeArray;
    return CPPAllocator.instance.makeArray!T(length, init);
}

Unqual!(ElementEncodingType!R)[] CPPNewArray(R)(R range) if (isInputRange!R && !isInfinite!R) {
    import std.experimental.allocator : makeArray;
    return CPPAllocator.instance.makeArray!T(range);
}

T[] CPPNewArray(T, R)(R range) if (isInputRange!R && !isInfinite!R) {
    import std.experimental.allocator : makeArray;
    return CPPAllocator.instance.makeArray!T(range);
}

auto CPPNewMultidimensionalArray(T, size_t N)(size_t[N] lengths...) {
    import std.experimental.allocator : makeMultidimensionalArray;
    return CPPAllocator.instance.makeMultidimensionalArray!T(lengths);
}

void CPPDelete(T) (auto ref T* p) {
    import std.experimental.allocator : dispose;
    CPPAllocator.instance.dispose(p);
}

void CPPDelete(T) (auto ref T p) if (is(T == class) || is(T == interface)) {
    import std.experimental.allocator : dispose;
    
    if (!p) {
        return;
    }
    
    destroy(p);
    CPPAllocator.instance.dispose(cast(void*) p); //Workaround for prevent error "Runtime type information is not supported for extern(C++) classes"
}

void CPPDelete(T) (auto ref T[] array) {
    import std.experimental.allocator : dispose;
    CPPAllocator.instance.dispose(array);
}

void CPPDeleteMultidimensionalArray(T)(auto ref T[] array) {
    import std.experimental.allocator : disposeMultidimensionalArray;
    CPPAllocator.instance.disposeMultidimensionalArray(array);
}

struct CPPAllocator {
    import std.experimental.allocator.common : platformAlignment;
    import core.stdcpp.xutility : __cpp_aligned_new;

    /**
     * Returns the global instance of this allocator type.
     * CppNew is thread-safe, all methods are shared.
     */
    static shared CPPAllocator instance;

    /**
     * The alignment is a static constant equal to `platformAlignment`, which
     * ensures proper alignment for any D data type.
     */    
    enum uint alignment = platformAlignment;

    /**
     * Allocates the size expressed in bytes.
     *
     * Params:
     *      bytes = Number of bytes to allocate.
     *
     * Returns:
     *      An array with allocated memory or null if out of memory. Returns null if called with size 0.
     */
    @trusted @nogc nothrow void[] allocate(size_t bytes) shared {
        import core.stdcpp.new_ : __cpp_new_nothrow;

        if (bytes == 0) {
            return null;
        }

        auto p = __cpp_new_nothrow(bytes);
        return p ? p[0 .. bytes] : null;
    }

    /**
     * Allocates the size expressed in bytes aligned by alignment.
     *
     * Params:
     *      bytes = Number of bytes to allocate.
     *      alignment = the minimal alignment of the allocated memory.
     *
     * Returns:
     *      An array with aligned allocated memory or null if out of memory. Returns null if called with size 0.
     */
    static if (__cpp_aligned_new) {
        @trusted @nogc nothrow void[] alignedAllocate(size_t bytes, uint alignment) shared {
            import core.stdcpp.new_ : __cpp_new_aligned_nothrow;
            
            if (bytes == 0) {
                return null;
            }
            
            auto p = __cpp_new_aligned_nothrow(bytes, alignment);
            return p ? p[0 .. bytes] : null;
        }
    }
    

    /**
     * Deallocate the specified memory block
     *
     * Params:
     *      b = The memory block to be deallocated.
     *
     * Returns:
     *   false if the array is null, otherwise true. 
     */
    @system @nogc nothrow bool deallocate(void[] b) shared {
        import core.stdcpp.new_ : __cpp_delete_nothrow;

        if (b is null) {
            return true;
        }

        __cpp_delete_nothrow(b.ptr);
        return true;
    }
}
