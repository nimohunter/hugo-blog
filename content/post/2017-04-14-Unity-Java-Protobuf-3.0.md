+++
author = "nimodai"
title = "Unity3d Java Protobuf"
date = "2017-04-14"
description = ""
tags = [
    "Unity3d",
]
+++
### Referece
1. [protobuf_for_unity](https://github.com/GongFaxin/protobuf_for_unity)
2. [Google Protobuf](https://developers.google.com/protocol-buffers/docs/javatutorial)

---

### Unity 
Thanks for [GongFaxin](https://github.com/GongFaxin), You can download his Code [protobuf_for_unity](https://github.com/GongFaxin/protobuf_for_unity), and Run in Unity 5.3, you can see a lot of Protobuf source code.

### Protobuf
Download the tools in [Protocol Buffers v3.0.0 Download link](https://github.com/google/protobuf/releases/tag/v3.0.0)

Then, follow the Google Tutorial.

```
protoc -I=$SRC_DIR --java_out=$DST_DIR $SRC_DIR/addressbook.proto
protoc -I=$SRC_DIR --csharp_out=$DST_DIR $SRC_DIR/addressbook.proto

```

Then you can get the Java code or C# code.

### Java
you will need the Jar: [protobuf-java-3.0.0.jar](https://repo1.maven.org/maven2/com/google/protobuf/protobuf-java/3.0.0/protobuf-java-3.0.0.jar)



