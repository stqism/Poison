![](https://kirara.ca/g/icon_512x512.png)

## Poison

Poison 2.0 is a rewrite of the original Poison.
(note: original README of Poison 1.x is [here](https://i.kirara.ca/vfzwp.md))

## Screenshots

![](http://wiki.tox.im/images/b/b3/Macgui1.png)  
![](https://kirara.ca/g/Poison-readme/main_window_windows.png)  

*More to come...*

## Testing builds

Download a copy of Poison from [Jenkins](http://jenkins.tox.im/).

## Coding guidelines
- The minimum compatibility target is 10.7.

## Translation guidelines
- For menus: if the option will take you to another part of the UI (say, pop up a sheet), always suffix it with "...".
- You can leave this out if ellipses aren't a [commonly-used] thing in your language.
- An ellipse is three dots.
- Do not translate the word "Tox" or the word "Poison" where they are used as proper nouns.
- Keep word choice consistent (e.g. do not refer to a friend as "友人" in one window,
  then "フレンド" in another)


## Automatic bootstrap
Starting with 1.1.3, Poison has the ability to automatically download a list of bootstrap servers to connect to.  
Don't worry, Poison will always ask you before downloading random nodelists off the Internet.  
If you want to use the list in your application, it is available [here](http://kirara.ca/poison/Nodefile). Each entry is on its own line, and the entry format is  
``[IP] [port] [public key] [comment ...]``  
* The IP may be a hostname, so you should try to resolve it before using it.  
* Since the comment is at the end, it is allowed to have spaces.  

## Licensing

