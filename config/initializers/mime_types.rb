# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf

# We use SVG for GraphViz
Mime::Type.register 'image/svg+xml', :svg
Mime::Type.register 'application/x-yaml', :yml
Mime::Type.register 'text/x-active-document', :ad
