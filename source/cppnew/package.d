module cppnew;

struct CPPNew {
    import std.experimental.allocator.common : platformAlignment;
    import core.stdcpp.xutility : __cpp_aligned_new;

    /**
     * Returns the global instance of this allocator type.
     * CppNew is thread-safe, all methods are shared.
     */
    static shared CPPNew instance;

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
