const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', ...defaultTheme.fontFamily.sans],
        body: ['Inter', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        surface: {
          DEFAULT: '#F8FAFC',
          card: '#FFFFFF',
          nested: '#F1F5F9',
          hover: '#E2E8F0',
        },
        accent: {
          DEFAULT: '#4F46E5',
          light: '#EEF2FF',
          medium: '#C7D2FE',
          dark: '#4338CA',
        },
        txt: {
          DEFAULT: '#1E293B',
          secondary: '#64748B',
          muted: '#94A3B8',
        },
        success: {
          DEFAULT: '#059669',
          light: '#ECFDF5',
        },
        danger: {
          DEFAULT: '#E11D48',
          light: '#FFF1F2',
        },
      },
      boxShadow: {
        'card': '0 4px 24px rgba(0, 0, 0, 0.06)',
        'card-hover': '0 8px 32px rgba(0, 0, 0, 0.08)',
        'glow': '0 0 24px rgba(79, 70, 229, 0.15)',
      },
      borderRadius: {
        '4xl': '2rem',
      },
    },
  },
  plugins: [],
}
