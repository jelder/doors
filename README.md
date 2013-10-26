# Doors

This project aims to solve the problem of people walking half way across the office only to find a room they want to use is occupied, then either waiting in line or returning to their desk. 

The solution is a minimal web page which could be consulted anonymously before making the trek. Think of it as *async IO for bathrooms*. In fact, we're still susceptible to the [thundering herd problem](http://en.wikipedia.org/wiki/Thundering_herd_problem).

## User Experience

![Desktop Screenshot](http://doors.boundless.com/screenshots/desktop_screenshot.png "Desktop Screenshot")

If using a compatible web browser (Safari, Chrome, and possibly others), a checkbox will appear next to each door. Checking this box subscribes to desktop notifications whenever the door is open. In Chrome, the notification will have the same color as the door.

## Behind the Scenes

The project relies on a hardware platform consisting of a microcontroller ([Digispark](http://digistump.com/products/1) running our Arduino code) connected to a pair of magnetic reed switches (of the type used in security systems), which is in turn connected to via USB to a computer running the Door Agent (ruby). The Door Agent is responsible for announcing changes in doors' states in real time to website visitors.

The website is a static site hosted on Amazon S3.

One of these devices is installed in the server room and is responsible for Gutenberg's door. Another is connected to the Mac mini behind the dashboard screen by the engineering team's couches.

## Future Plans

* A live counter of the number of people who have the site open at that moment, or who are checking a particular door. This is available through Google Analytics, but I don't know about accessing that via a public API. Something more special purpose may exist.
* A Raspberry Pi port of the Arduino/Ruby part of the app in order to take advantage of that platform's better WiFi support. GoLang would be a great fit here.
* Some kind of historical trends display, so hotspots can be avoided.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request