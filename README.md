# Charty - Visualizing your data in Ruby

Charty is open-source Ruby library for visualizing your data in a simple way.
In Charty, you need to write very few lines of code for representing what you want to do.
It lets you focus on your analysis of data, instead of plotting.

![](https://github.com/red-data-tools/charty/raw/master/images/design_concept.png)

## Installation

To be described later.

## Usage

```ruby
require 'charty'
charty = Charty::Main.new(:matplot)

bar = charty.bar do
  series [0,1,2,3,4], [10,40,20,90,70]
  series [0,1,2,3,4], [90,80,70,60,50]
  series [0,1,2,3,4,5,6,7,8], [50,60,20,30,10, 90, 0, 100, 50]
  range x: 0..10, y: 1..100
  xlabel 'foo'
  ylabel 'bar'
  title 'bar plot'
end
bar.render
```

## Acknowledgements

- The concepts of this library is borrowed from Python's [HoloViews](http://holoviews.org/) and Julia's [Plots ecosystem](https://juliaplots.github.io/).

## Authors

- Kenta Murata \<mrkn@mrkn.jp\>

## License

MIT License
