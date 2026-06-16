/** @type {import('tailwindcss').Config} */

const DT = require('tailwindcss/defaultTheme');
// import * as aspect from '@tailwindcss/aspect-ratio'
// import * as forms from '@tailwindcss/forms'
// import * as lineClamp from '@tailwindcss/line-clamp'
// import * as typography from '@tailwindcss/typography'

export default {
  content: {
    files: [
      './src/**/*.{html,js,svelte,ts,coffee,pug}',
    ]
  },
  theme: {
    extend: {
      fontFamily: {
        sans: [
          'Roboto',
          ...DT.fontFamily.sans,
        ],
        mono: [
          'Source Code Pro',
          ...DT.fontFamily.mono,
        ],
      },
    },
  },
  plugins: [
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/forms')({ strategy: 'class', }),
    require('@tailwindcss/typography'),
  ],
}
