# openbd-journal
Profile and produce code-coverage reports for OpenBD applications

The Open Bluedragon Journaling Tool is a means to perform in-depth analysis of code coverage, file usage, and line-by-line execution traces of your OpenBD CFML applications on a per-request basis. This tool is intended to live inside an OpenBD web application as another directory. The Journaling Tool consumes journal files produced by the Journaling feature in OpenBD [currently available in the nightly build].

# Documentation
Documentation on how to enable and configure journaling in your OpenBD web application can be found at http://openbd.org/manual/?/journal

# Installation
Download the OpenBD Journaling Tool zip, then unzip this into your OpenBD web application. The Journaling Tool is now able to be accessed as if it were another directory within your app. Upon entering the tool, you will be prompted for a password. The password is currently "openbdjournal", however in the near future the password will be configured via the openbluedragon.xml. After gaining access to the tool, you will find the dashboard, where there will be a listing of the journal files available for analysis.

# Dashboard
Here you find a listing of journal files ordered by creation date. Each entry is accompanied by the page the journal request occurred on, the journal file name, the size of the journal file, and duration (ms) that the request lasted. Two buttons are provided on each entry, one to access the coverage statistics for the request, and one to access the line-by-line trace of the request.

# Enable Journaling
On the dashboard, above the journal entries table, you will find the controls for turning journaling on.

Capture Method controls whether the journaling will last for one request (using the url parameter method of enabling) or indefinitely (using the cookie method of enabling).

Capture URL specifies the page the request will begin on.

Password is the journaling password, as specified in the openbluedragon.xml of your web application.

# Code Coverage
Entering the code coverage portion of the tool yields many charts depicting various code coverage metrics. Heat maps are available to show the amount of code coverage per file, amount of blank lines per file, and number of script/tag lines per file, among other per-file percentages.

The coverage section of the tool also contains a tree depicting the directory structure of the web application. From the root of the web application, each directory following is represented with another node in the tree. Leaves in the tree represent individual CFML files. The file leaves are colored on the same scale as the heat maps to indicate their pertentage of code coverage.

# Compound Journal Files
The dashboard also has the ability to compound several journal files into a single journal file in order to analyze code coverage over multiple requests. Select multiple journal files on the dashboard, then use the control beneath the listing to create a compound file. Once the compound file is generated, it will be shown in the journal file listing. You will be able to view code coverage for the compound file, but not line-by-line traces.

# Line-by-line Code Trace
Playback controls to play through the journal, pause playback, and step forward and backward through the file are located near the top. Settings for how many source files to show at a given time and the playback speed (in lines per second) are also to the right of the playback controls.

The playback timeline shows the periods of time spent in each file touched during the request. A vertical marker shows where in the request duration the playback is at a given point. Clicking on the playback timeline will move the playback to the point where the timeline was clicked.

During playback, the code trace will present the source of the file that was being executed during current point in the journal playback, as well as highlight the specific line in that source code that was being executed.


# Latest Version


# Bug Reporting


# Contributing