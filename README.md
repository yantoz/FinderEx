# FinderEx
MacOS Finder Sync Extension to Allow Adding Custom Actions

## Description

FinderEx is a small tool to allow adding custom actios to context menu which is shown when one right clicked inside folder or folder items (folders and files). It consists of two parts: the menu items editor and the finder sync extension that adds context menu items depending on what finder items one selected and then right clicked.

## Motivation

I came from Windows world, and I missed Windows Explorer's context menu to quickly apply actions on folders and files. This is my first project with Xcode and OSX, so it also serves as my playground to learn Swift, Cocoa, Interface Builder, Delegations, Controllers, FinderSync, XPC and all other Mac specific things that I was not exposed to before I joined the Mac world.

It took me countless visits to Stack Overflow as Mac newbie to get experts help to make this happen, so I would like to give it back to the community by making it free and open source. 

## How to Use

Just clone this repository, open the Xcode project and build.

FinderEx embeds FinderSync extension component, which would be installed when the program runs. It would check if the extension was enabled and if not, it would open the Preference window for you to enable it. Please do so to allow it to do its job.

The main window is the menu items editor where you can define your files categories (Image files, Document files, etc.).
There are several predefined categories that are created automatically and cannot be deleted. 
Other categories can be added and specifies group of files based on extensions (file suffixes). 
Several extensions can be defined for a category by joining them with semicolons.

When item(s) are right clicked in Finder, all menu items from all matched categories would be added to the context menu, so at least all menu items in the "All Items" category will always be added. When a container (blank space in Finder is right clicked, only menu items from "Container" category would be added.

Menu items for each category can be added/edited/deleted by selecting the category and then right clicking the category or the "Right-click Here ..." area. This would bring up the menu. Select an item to edit or delete it or select "Add New Item ..." to add new item.

Each menu item, when selected, can be defined to do action that you choose: run an Applescript, a Bash script or an Automator workflow.
They would get selected items' path as their input, as arguments to Applescripts and Bash scripts and as standard input to Automator workflows.
Applescripts and Bash scripts can be written directly in the editor so you do not have to create and store script files, although you can do so as well. Automator workflows need to be pre-created, and you need to tell FinderEx which .wflow file to launch.

FinderEx editor loads and saves configuration as YAML file in ~/Library/FinderEx/config.yaml but the FinderSync extension loads configurations from both /Library/FinderEx/config.yaml (system wide) and ~/Library/FinderEx/config.yaml (user specific), so you can create system wide configuration available for all users as well as one for yourself.

## Disclaimer

This software is free but comes without warranty in any form. 
I shall not be liable for any damage that it may cause to your computer, storage, life, whatever, especially if you write scripts that do dangerous things. 
That said, I hope this software could be useful and boost your productivity, as it is for me.

