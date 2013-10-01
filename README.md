This project aims to solve the problem of people walking half way across the office only to find that both bathrooms are occupied, then either waiting in line or returning to their desk. A similar problem exists for conference rooms. 

The solution is a minimal web page which could be consulted anonymously before making the trek. Think of it as '''async IO for bathrooms''', although we're susceptible to the [thundering herd problem](http://en.wikipedia.org/wiki/Thundering_herd_problem).

An Arduino is board connected to a pair of magnetic reed switches, as in a security system, each mounted to one of the bathrooms' doors. The sketch prints to the serial port every time one of the switches changes state. All we need from the Arduino is to tell us which door just transitioned into which state. The digispark units I'm donating to this project are fairly limited, so this is ideal.

Some trivial circuitry is required to support this. Here's a sketch similar to what we need: http://arduino.cc/en/Tutorial/ButtonStateChange

The Arduino is connected via USB to the Mac mini which until now was only running Geckoboard. A ruby script is listening to the serial port and for each change event, performs two actions in parallel:

1. Sends a Pusher event with the door ID and the new state.
2. Updates a JSON file on S3 named for the door ID, with the doors current state and a timestamp.

Finally, we have an [AngularJS](http://angularjs.org/) app which loads each of the doors' JSON files. Each door's current state, and how long it's been in that state, is presented relatively, as provided by http://timeago.yarp.com/. Pusher events update the display, and trigger desktop notifications if the user has allowed them.

## Future Plans

* A live counter of the number of people who have the site open at that moment. This is available through Google Analytics, but I don't know about accessing that via a public API. Something more special purpose may exist.

* A Raspberry Pi port of the Arduino/Ruby part of the app in order to take advantage of that platform's better WiFi support. GoLang would be a great fit here.

* Some kind of historical trends display, so hotspots can be avoided.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request