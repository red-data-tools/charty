require "charty"
require "datasets"
require "matplotlib"

Charty::Backends.use(:pyplot)
Matplotlib.use(:agg)

penguins = Datasets::Penguins.new

Charty.box_plot(data: penguins, x: :species, y: :body_mass_g)
      .save("penguins_species_body_mass_g_box_plot_v.png")

Charty.box_plot(data: penguins, x: :body_mass_g, y: :species)
      .save("penguins_species_body_mass_g_box_plot_h.png")

Charty.box_plot(data: penguins, x: :species, y: :body_mass_g, color: :sex)
      .save("penguins_species_body_mass_g_sex_box_plot_v.png")
