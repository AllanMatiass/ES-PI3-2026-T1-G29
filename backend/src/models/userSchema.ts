export type User = {
  id: string
  firebaseUid: string
  name: string
  email: string
  cpf: string

  walletBalance: number

  createdAt: Date
}

export type CreateUserDTO = {
  name: string
  email: string
  cpf: string
  password: string
}

export type LoginDTO = {
  email: string,
  password: string
}