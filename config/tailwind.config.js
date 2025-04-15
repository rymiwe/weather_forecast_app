module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/**/*.css',
  ],
  safelist: [
    'bg-blue-400', 'bg-blue-500', 'bg-blue-600', 'bg-blue-700', 'bg-red-600', 'bg-green-600',
    'rounded-xl', 'shadow-md', 'p-6', 'text-black', 'text-base', 'font-bold', 'tracking-wide'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
