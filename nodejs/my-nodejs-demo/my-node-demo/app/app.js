'use strict';

var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');

var app = express();
// view engine setup
if (app.get('env') === 'development') {
  app.set('views', path.join(__dirname, 'views', 'src')); // 指定node使用的模板路径，模板里面会引用到css,js(通过下面的express.static指定)
} else {
  app.set('views', path.join(__dirname, 'views', 'dist'));
}

app.set('view engine', 'ejs');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());

if (app.get('env') === 'development') {
  app.use(express.static(path.join(process.cwd())));
  app.use(express.static(path.join(process.cwd(), 'tmp')));// 开发环境下，需将tmp目录加为node的资源目录以便可以访问到js、css资源
  app.use(express.static(path.join(process.cwd(), 'assets', 'distribution')));
  app.use(require('connect-livereload')({ port: 35729 }));
  app.use(require('mocer')(__dirname + path.sep + 'mocks'));
} else {
  var basePath = process.cwd();
  if (basePath.endsWith('bin')) {
    basePath = basePath.slice(0, basePath.length - 4);
  }

  app.use(express.static(path.join(basePath, 'pub')));// 生产环境下，需将pub目录加为node的资源目录以便可以访问到js、css后面的资源
}

// 路由设置，如：/finance的路由都走./routes/finance。里面无需再设置finance的前缀
app.use('/', require('./routes/index'));
app.use('/finance', require('./routes/finance'));
app.use('/testxht', require('./routes/testxht'));

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers
// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
  app.use(function(err, req, res, next) {
    res.status(err.status || 500);
    res.render('error', { message: err.message, error: err });
  });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res, next) {
  res.status(err.status || 500);
  res.render('error', { message: err.message, error: { } });
});

module.exports = app;
