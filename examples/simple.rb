require "charty"

Dir.chdir __dir__

charty = Charty::Plotter.new(:pyplot)
figure = charty.bar do
  series [1, 2, 3, 4, 5], [10, 20, 25, 30, 40], label: "a"
  series [1, 2, 3, 4, 5], [20, 10, 15, 20, 50], label: "b"
  series [1, 2, 3, 4, 5], [30, 25, 20, 10,  5], label: "cd"
end
figure.save("simple_bar.png")

figure = charty.barh do
  series [1, 2, 3, 4, 5], [10, 20, 25, 30, 40], label: "a"
  series [1, 2, 3, 4, 5], [20, 10, 15, 20, 50], label: "b"
  series [1, 2, 3, 4, 5], [30, 25, 20, 10,  5], label: "cd"
end
figure.save("simple_barh.png")

figure = charty.curve do
  series [1, 2, 3, 4, 5], [10, 20, 25, 30, 40], label: "a"
  series [1, 2, 3, 4, 5], [20, 10, 15, 20, 50], label: "b"
  series [1, 2, 3, 4, 5], [30, 25, 20, 10,  5], label: "cd"
end
figure.save("simple_curve.png")

figure = charty.box_plot do
  data [
         [1, 3, 7, *Array.new(20) { rand(40..70) }, 100, 110, 120],
         [1, 4, 7, *Array.new(80) { rand(35..80) }, 130, 135, 145],
         [0, 2, 8, *Array.new(20) { rand(60..90) }, 150, 160, 165]
       ]
  xlabel "foo"
  ylabel "bar"
  title "box plot"
end
figure.save("simple_box_plot.png")

figure = charty.scatter do
  series 0..10, (0..1).step(0.1), label: 'sample1'
  series 0..5, (0..1).step(0.2), label: 'sample2'
  series [0, 1, 2, 3, 4], [0, -0.1, -0.5, -0.5, 0.1]
end
figure.save("simple_scatter.png")

figure = charty.bubble do
  series 0..10, (0..1).step(0.1), [10, 100, 1000, 20, 200, 2000, 5, 50, 500, 4, 40], label: 'sample1'
  series 0..5, (0..1).step(0.2), [1, 10, 100, 1000, 500, 100], label: 'sample2'
  series [0, 1, 2, 3, 4], [0, -0.1, -0.5, -0.5, 0.1], [40, 30, 200, 10, 5]
  range x: 0..10, y: -1..1
  xlabel 'x label'
  ylabel 'y label'
  title 'bubble sample'
end
figure.save("simple_bubble.png")

def randn(n, mu=0.0, sigma=1.0)
  Array.new(n) do
    x, y = rand, rand
    sigma * Math.sqrt(-2 * Math.log(x)) * Math.cos(2 * Math::PI * y) + mu
  end
end

figure = charty.hist do
  data [ randn(1000, 0.0, 1.0),
         randn(100, 2.0, 2.0) ]
  title "histogram sample"
end
figure.save("simple_hist.png")
