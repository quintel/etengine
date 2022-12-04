const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./public/*.html",
    "./app/assets/images/**/*.svg",
    "./app/components/**/*.{erb,rb}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      colors: {
        midnight: {
          50: "#f2f5fd",
          100: "#dde6f8",
          200: "#ccdcf5",
          300: "#a6c2ed",
          400: "#7da4e3",
          500: "#5b80d7",
          600: "#4f6ec9",
          700: "#3b54ba",
          800: "#2940a8",
          900: "#31407d",
        },
        gray: {
          350: "#b7bcc5",
        },
      },
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
  ],
};
