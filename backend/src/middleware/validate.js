const HttpError = require('../utils/httpError');

function validate(schema) {
  return (req, res, next) => {
    const result = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params
    });

    if (!result.success) {
      return next(
        new HttpError(
          400,
          'Dữ liệu không hợp lệ.',
          result.error.issues.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message
          }))
        )
      );
    }

    req.validated = result.data;
    return next();
  };
}

module.exports = validate;
