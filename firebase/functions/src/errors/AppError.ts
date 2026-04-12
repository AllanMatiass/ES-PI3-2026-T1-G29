// Autor: Allan Giovanni Matias Paes
export class AppError extends Error {
  public readonly statusCode: number;

  constructor({
    message,
    statusCode,
  }: {
    message: string;
    statusCode: number;
  }) {
    super(message);

    this.statusCode = statusCode;

    Object.setPrototypeOf(this, AppError.prototype);
  }
}
