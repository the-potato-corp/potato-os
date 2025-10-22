# What is PotatoOS?
PotatoOS is a potato-themed operating system designed to run on a "host" OS, your existing installation (Windows, Linux, MacOS), instead of bare-metal. Unlike a traditional operating system that runs directly on bare hardware (bare-metal) or within a strictly isolated virtual machine (VM), PotatoOS runs as a single, full-screen application built using the Godot Engine.

# How is it coded?
The entire PotatoOS ecosystem, including the shell, system utilities, and core applications, is built and driven by the STARCH programming language.

STARCH is a modern, C-styled scripting language optimized¹ for performance within the Godot runtime. Its primary function is to act as the native programming interface for PotatoOS, providing seamless, high-level access to all system functions (the STARCH System APIs).

# What is this repo?
The PotatoOS code is stored in many different repositories.
* [Godot](https://github.com/the-potato-corp/potato-os): This stores all the code for PotatoOS's Godot application. It contains important scripts for execution and a boot system.
* [Wiki](https://github.com/the-potato-corp/potatoos-docs): This is the documentation for PotatoOS. It contains information on how to use the system as well as how to code using STARCH.
* [Website](https://github.com/potato-os/potato-os.github.io): This is the website for PotatoOS. Eventually it will have a home page and some other information, but is also intended to host system files and the default filesystem.

# Note
PotatoOS is in very early development and is currently missing a lot of information. We reccommend that you come back here later if you'd like to download a released build.

¹ It's not at all.
