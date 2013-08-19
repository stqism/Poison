![](https://kirara.ca/g/icon_512x512.png)

## Poison

Poison is a Mac-native GUI built on the [Tox](https://github.com/irungentoo/ProjectTox-Core) core, aiming to make Tox blend in with the look and feel of OS X.  
Most features **sort of work**, but **chatting in particular is quite buggy**. I recommend you keep using the programs included with Core for now.  
[![Build Status](https://travis-ci.org/stal888/Poison.png)](https://travis-ci.org/stal888/Poison)

## Screenshots

Since Poison is in early development, the UI might change in the near future. Here's what it looks like right now, though:  

![](http://wiki.tox.im/images/b/b3/Macgui1.png)  

*More to come...*

## Testing builds

... are not available yet. Check back later!  
You can also build manually (requires libsodium installed to /usr/local at the moment). Just run ``xcodebuild -workspace Poison.xcworkspace -scheme Poison``.  

## Coding guidelines
- If you break compatibility with 10.6, I will break you.

## Translation guidelines
- For menus: if the option will take you to another part of the UI (say, pop up a sheet), always suffix it with "...".
- You can leave this out if ellipses aren't a [commonly-used] thing in your language.
- An ellipse is three dots. Not four, not ten, three.

## Automatic bootstrap
Starting with 1.1.3, Poison has the ability to automatically download a list of bootstrap servers to connect to.  
Don't worry, Poison will always ask you before downloading random nodelists off the Internet.  
If you want to use the list in your application, it is available [here](http://kirara.ca/poison/Nodefile). Each entry is on its own line, and the entry format is  
``[IP] [port] [public key] [comment ...]``  
* The IP may be a hostname, so you should try to resolve it before using it.  
* Since the comment is at the end, it is allowed to have spaces.  

## Licensing

All assets used in Poison, with the exception of icons, PXListView, and scrypt, are licensed under GPLv3.  
PXListView is licensed under New BSD, see the readme in its directory for more details.  
scrypt is licensed under the 2-clause BSD license, see the readme in its directory and header files for more details.  
If you want to use the icon for something that isn't an application, ask me on the Tox IRC. I'll probably let you use it if the use case isn't stupid. (except for the Shiina icon, I'm fairly sure that it is copyrighted and not even I am allowed to use it)
