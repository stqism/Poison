![](https://kirara.ca/g/icon_512x512.png)

## Poison

Poison is a Mac-native GUI built on the [Tox](https://github.com/irungentoo/ProjectTox-Core) core, aiming to make Tox blend in with the look and feel of OS X.

[![Build Status](https://travis-ci.org/stal888/Poison.png)](https://travis-ci.org/stal888/Poison)

## Screenshots

Since Poison is in early development, the UI might change in the near future. Here's what it looks like right now, though:  

![](https://kirara.ca/g/Poison-readme/login_window.png)  

*More to come...*

## Testing builds

... are not available yet. Check back later!  
You can also build manually (requires libsodium installed to /usr/local at the moment). Just run ``xcodebuild -workspace Poison.xcworkspace -scheme Poison``.  

## Coding guidelines
- If you break compatibility with 10.6, I will break you.

## Licensing

All assets used in Poison, with the exception of icons, PXListView, and scrypt, are licensed under GPLv3.  
PXListView is licensed under New BSD, see the readme in its directory for more details.  
scrypt is licensed under the 2-clause BSD license, see the readme in its directory and header files for more details.  
If you want to use the icon for something that isn't an application, ask me on the Tox IRC. I'll probably let you use it if the use case isn't stupid. (except for the Shiina icon, I'm fairly sure that it is copyrighted and not even I am allowed to use it)
