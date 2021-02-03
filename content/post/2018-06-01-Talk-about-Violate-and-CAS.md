+++
author = "nimodai"
title = "Talk-about-Violate-and-CAS"
date = "2018-06-01"
description = ""
tags = [
    "Java",
]
+++

# Violate 与 CAS 原子性探究
关于原子性的问题，很多的Blog进行了分析和解释，这里只是想更明确的解释清楚。

### Violate

保证所有的线程可见性，但是不保证原子性。所以只有set和get场景使用violate是非常合适的，能够保证修改能够快速的被所有的线程所识别。但是不适合于getAndOperate。

而violate之所以可以达到线程可见性是因为内存屏障的存在，violate修饰的对象会在读操作之前加内存屏障，在写操作之后加内存屏障。而内存屏障的存在就是打破CPU的指令重排序。我们知道CPU会利用流水进行指令的重排序，来实现保证输出结果不发生改变的情况下进行性能优化，而内存屏障则是打破这种重排序，内存屏障保证对在内存屏障之前指令必须全部执行完，才能执行内存屏障后的指令。所以在对一个violate对象修改之后，所有的之后的操作必须等待这个violate对象修改完之后才能进行操作。

内存屏障的第二个作用是告诉其他CPU这块数据已经是脏数据了，可以强制刷新其他CPU的对于这个Violate对象的缓存。一个写屏障会把这个屏障前写入的数据强制刷新到Cache，这样任何试图读取该数据的线程将得到最新值。

但是，Violate依然不具备原子性，比如对一个violate 的Integer进行+1操作，jvm指令为：

```assembly
mov    0xc(%r10),%r8d ; Load
inc    %r8d           ; Increment
mov    %r8d,0xc(%r10) ; Store
lock addl $0x0,(%rsp) ; StoreLoad Barrier
```

其中Load到StoreLoad Barrier 并不是原子的，中间任何一部分都可能被打断，比如在Increment阶段，被打断，数值被修改，之后再继续执行写回就出错了。

### CAS
CAS操作来自于Java的**unsafe**包，而CAS的原子性也是由unsafe包提供的native方法提供的。CAS是所有原子变量的原子性的基础，原因是因为最终的native的操作会演化为一条CPU指令**cmpxchg** ，而不是多条CPU指令，所以这一条指令是不会被多线程调度机制打断的，而且对于大多数CPU都是支持的，而少量不支持的CPU会自动加lock进行保证这条指令被原子执行。

关注一下`AtomicReference` 的`compareAndSet `方法，这是一个标准的原子操作：
```java
/**
* Atomically sets the value to the given updated value
* if the current value {@code ==} the expected value.
* @param expect the expected value
* @param update the new value
* @return {@code true} if successful. False return indicates that
* the actual value was not equal to the expected value.
*/
public final boolean compareAndSet(V expect, V update) {
  return unsafe.compareAndSwapObject(this, valueOffset, expect, update);
}
```

继续往下看`unsafe.compareAndSwapObject`:

```java
public final native boolean compareAndSwapObject(Object var1, long var2, Object var4, Object var5);
```

这已经是native方法了，更详细的代码是C++实现的。继续往下看:

```C++
UNSAFE_ENTRY(jboolean, Unsafe_CompareAndSwapObject(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jobject e_h, jobject x_h))
  UnsafeWrapper("Unsafe_CompareAndSwapObject");
  oop x = JNIHandles::resolve(x_h); // 新值
  oop e = JNIHandles::resolve(e_h); // 预期值
  oop p = JNIHandles::resolve(obj);
  HeapWord* addr = (HeapWord *)index_oop_from_field_offset_long(p, offset);// 在内存中的具体位置
  oop res = oopDesc::atomic_compare_exchange_oop(x, addr, e, true);// 调用了另一个方法
  jboolean success  = (res == e);  // 如果返回的res等于e，则判定满足compare条件（说明res应该为内存中的当前值），但实际上会有ABA的问题
  if (success) // success为true时，说明此时已经交换成功（调用的是最底层的cmpxchg指令）
    update_barrier_set((void*)addr, x); // 每次Reference类型数据写操作时，都会产生一个Write Barrier暂时中断操作，配合垃圾收集器
  return success;
UNSAFE_END
```

再往下看，这里调用了`atomic_compare_exchange_oop`:

```c++
inline oop oopDesc::atomic_compare_exchange_oop(oop exchange_value,
                                                volatile HeapWord *dest,
                                                oop compare_value,
                                                bool prebarrier) {
  if (UseCompressedOops) { // 如果使用了压缩普通对象指针(CompressedOops)，有一个重新编解码的过程
    if (prebarrier) {
      update_barrier_set_pre((narrowOop*)dest, exchange_value);
    }
    // encode exchange and compare value from oop to T
    narrowOop val = encode_heap_oop(exchange_value); // 新值
    narrowOop cmp = encode_heap_oop(compare_value); // 预期值

    narrowOop old = (narrowOop) Atomic::cmpxchg(val, (narrowOop*)dest, cmp); // 这里调用的方法见文章最后，因为被压缩到了32位，所以可以用int操作  
    // decode old from T to oop
    return decode_heap_oop(old);
  } else {
    if (prebarrier) {
      update_barrier_set_pre((oop*)dest, exchange_value);
    }
    return (oop)Atomic::cmpxchg_ptr(exchange_value, (oop*)dest, compare_value); // 可以看到这里继续调用了其他方法
  }
}
```

再往下看`Atomic::cmpxchg`：

```c++
inline jlong    Atomic::cmpxchg    (jlong    exchange_value, volatile jlong*    dest, jlong    compare_value) {
  int mp = os::is_MP();
  jint ex_lo  = (jint)exchange_value;
  jint ex_hi  = *( ((jint*)&exchange_value) + 1 );
  jint cmp_lo = (jint)compare_value;
  jint cmp_hi = *( ((jint*)&compare_value) + 1 );
  __asm {
    push ebx
    push edi
    mov eax, cmp_lo
    mov edx, cmp_hi
    mov edi, dest
    mov ebx, ex_lo
    mov ecx, ex_hi
    LOCK_IF_MP(mp)
    cmpxchg8b qword ptr [edi]
    pop edi
    pop ebx
  }
}
```

然后终于看到了`cmpxchg8b` 意为 compare and exchange 8byte，比较并交换8字节。8字节，即64bit，个人认为正好是64bit的寻址对象。

---

参考文章：

1. [并发实战](https://blog.csdn.net/qqqqq1993qqqqq/article/details/75211993)
2. [为什么volatile不能保证原子性而Atomic可以？](http://www.cnblogs.com/Mainz/p/3556430.html)