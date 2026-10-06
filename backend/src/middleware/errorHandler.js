function notFoundHandler(req, res, next) {
  res.status(404).json({
    message: `Không tìm thấy đường dẫn ${req.method} ${req.originalUrl}.`
  });
}

function errorHandler(error, req, res, next) {
  const statusCode = error.statusCode || 500;

  if (error.code === 11000) {
    return res.status(409).json({
      message: 'Email này đã có tài khoản.'
    });
  }

  return res.status(statusCode).json({
    message: error.message || 'Lỗi máy chủ.',
    details: error.details
  });
}

module.exports = {
  errorHandler,
  notFoundHandler
};
