const { environment } = require('@rails/webpacker')
const erb = require('./loaders/erb')

const webpack = require("webpack")
environment.plugins.append("Provide", new webpack.ProvidePlugin({
$: 'jquery',
jQuery: 'jquery',
Popper: ['popper.js', 'default']
}))

const config = environment.toWebpackConfig();


config.resolve.alias = {
  jquery: 'jquery/src/jquery'
 };
// bootstrap jquery setup


environment.loaders.prepend('erb', erb)
module.exports = environment
