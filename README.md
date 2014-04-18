
![](http://vexx.us/Images/poison1.png)
***
Poison is a Mac client for [Tox](https://github.com/irungentoo/ProjecTox-Core), with support for file sharing, multiple profiles, group messaging, and more. Built with precision and care, Poison follows strict guidelines to maintaining the look and feel of OS X. While it's still in its infancy stage, most of Poison's features work, but support for A/V is in the works as more features are in the works.

*Please make any further pull requests to the 2.0 branch.*




![](http://vexx.us/Examples/Poison/lady_stoneheart.png)


Poison is built to support Notification Center, so you never miss a message, and with an extensive array of options, you can customize Poison to be your own.

<img src="http://vexx.us/Images/notification-group.png"><img src="http://vexx.us/Images/notification-online.png">





## Downloads

You can download nightly versions of Poison, which are automatically built for every commit made  [here](https://c1cf.https.cdn.softlayer.net/80C1CF/192.254.75.110:8080/job/Poison_OS_X/lastSuccessfulBuild/artifact/arc/poison.zip).
You can also build manually (requires libsodium installed to /usr/local at the moment). Just run ``xcodebuild -workspace Poison.xcworkspace -scheme Poison``.  

## Contribution Guidelines
###Coding
* If you break compatibility with 10.7, I will break you.

### Translations
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

### Translation text

- For menus: if the option will take you to another part of the UI (say, pop up a sheet), suffix it with an ellipse.
- Do not translate the word "Tox" or the word "Poison" where they are used as proper nouns.
- Keep word choice consistent (e.g. do not refer to a friend as "Contact" in one window,
  then "Friend" in another)

## Automatic Bootstrapping
Starting with 1.1.3, Poison has the ability to automagically download find the best Tox bootstrap server to connect to. Users still have the option to specify a custom Tox Node.

## Licensing

* All assets used in Poison, with the exception of icons, PXListView, and scrypt, are licensed under GPLv3.  
* PXListView is licensed under New BSD, see the readme in its directory for more details.  
* scrypt is licensed under the 2-clause BSD license, see the readme in its directory and header files for more details.  
* If you want to use the icon for something that isn't an application, ask me on the Tox IRC. I'll probably let you use it if the use case isn't stupid. (except for the Shiina icon, I'm fairly sure that it is copyrighted and not even I am allowed to use it)
