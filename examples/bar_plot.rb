# This example generates box_plot results in README.md

require "charty"
require "datasets"
require "matplotlib"

Charty::Backends.use(:pyplot)
Matplotlib.use(:agg)

penguins = Datasets::Penguins.new

Charty.bar_plot(data: penguins, x: :species, y: :body_mass_g)
      .save("penguins_species_body_mass_g_bar_plot_v.png")

Charty.bar_plot(data: penguins, x: :body_mass_g, y: :species)
      .save("penguins_species_body_mass_g_bar_plot_h.png")

Charty.bar_plot(data: penguins, x: :species, y: :body_mass_g, color: :sex)
      .save("penguins_species_body_mass_g_sex_bar_plot_v.png")
