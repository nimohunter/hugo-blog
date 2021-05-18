+++
author = "nimodai"
title = "Kmp-algorithm-with-rust"
date = "2021-05-18"
description = ""
tags = [
    "Rust",
]
+++

最近觉得Rust很好玩， 顺便写了一个Rust版本的Kmp算法。

```rust
fn main() {
    let main_str = String::from("ababcaaabaababacbaba");
    let small_str = String::from("ca");
    let pos = find_pos_by_kmp(&main_str, &small_str);
    println!("find pos = {}", pos)
}

fn find_pos_by_kmp(s: &String, t: &String) -> i32 {
    let next = build_next_arr(t);

    return find_pos_with_next_arr(s, t, &next[..]);
}

fn find_pos_with_next_arr(s: &String, t: &String, next: &[usize]) -> i32 {
    let length_t = t.len();
    let length_s = s.len();
    let t = t.as_bytes();
    let s = s.as_bytes();
    let mut x = 0;
    let mut i = 0;

    while i < length_s && x < length_t {
        // println!("i = {}, x = {}", i, x);
        if s[i] == t[x] {
            i += 1;
            x += 1;
        } else if x > 0 {
            x = next[x - 1];
        } else {
            i += 1;
        }
    }
    if x == length_t {
        // find the pos
        return (i - x) as i32;
    }
    return -1;
}

fn build_next_arr(t: &String) -> Vec<usize> {
    let mut v: Vec<usize> = vec![];
    v.push(0);
    let length = t.len();
    let t = t.as_bytes();
    let mut x = 0;
    let mut i = 1;
    while i < length {
        if t[i] == t[x] {
            v.push(x + 1);
            i += 1;
            x += 1;
        } else if x > 0 {
            x = v[x - 1];
        } else {
            v.push(0);
            i += 1;
        }
    }
    return v;
}

```