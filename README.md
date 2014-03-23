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

## Translating Poison into your language(s)

### How-to

0. (If you don't have Xcode installed, skip this step) Run
   `./translation_helper.sh genstrings` in the project root.
1. `cd` to `resources/strings`.
2. Copy `en.lproj` to a folder for your language's code. Apple tells you
   how to figure those out [here](https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpinternational/Articles/LanguageDesignations.html).
3. Translate the `Localizable.strings` file in your new folder.
4. (If you don't have Xcode installed, skip this step) Run
   `./translation_helper.sh update` in the project root. It might spit out some
   warnings, just ignore them.
5. `cd` to `resources/interfaces/TL/strings`. Again, copy `en.lproj` to a new
   folder, with the same code you used in step 2.
6. Translate the files in your new folder.
7. Do the GitHub thing.
8. You are done! Thank you for helping translate Poison.

### Guidelines for text

- For menus: if the option will take you to another part of the UI (say, pop up a sheet), suffix it with an ellipse.
- Do not translate the word "Tox" or the word "Poison" where they are used as proper nouns.
- Keep word choice consistent (e.g. do not refer to a friend as "Contact" in one window,
  then "Friend" in another)

## Automatic bootstrap
Starting with 1.1.3, Poison has the ability to automatically download a list of bootstrap servers to connect to.  
Don't worry, Poison will always ask you before downloading random nodelists off the Internet.  
If you want to use the list in your application, it is available [here](http://kirara.ca/poison/Nodefile). Each entry is on its own line, and the entry format is  
``[IP] [port] [public key] [comment ...]``  
* The IP may be a hostname, so you should try to resolve it before using it.  
* Since the comment is at the end, it is allowed to have spaces.  

## Licensing

