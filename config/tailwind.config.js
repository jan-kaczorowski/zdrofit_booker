const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './config/initializers/simple_form_tailwind.rb',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        surface: {
          DEFAULT: '#060e20',
          dim: '#0a1228',
          container: '#0f1930',
          'container-low': '#0c1528',
          'container-high': '#152035',
          'container-highest': '#192540',
        },
        'on-surface': {
          DEFAULT: '#ffffff',
          variant: '#a3aac4',
        },
        'on-background': '#dee5ff',
        primary: {
          DEFAULT: '#a7a5ff',
          dim: '#645efb',
          container: '#9795ff',
        },
        'outline-variant': '#40485d',
        'error-dim': '#d73357',
      },
      boxShadow: {
        'ambient': '0px 20px 40px rgba(100, 94, 251, 0.08)',
        'ambient-lg': '0px 20px 40px rgba(100, 94, 251, 0.15)',
        'glow': '0 0 30px rgba(100, 94, 251, 0.12)',
      },
      borderRadius: {
        '4xl': '2rem',
      },
    },
  },
  plugins: [],
}
