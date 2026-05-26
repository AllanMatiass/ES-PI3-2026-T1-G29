// Autor: Allan Giovanni Matias Paes - 25008211

export type SignupRequestDTO = {
  name: string;
  email: string;
  cpf: string;
  phone: string;
  password: string;
};

export type SignupResponseDTO = {
  uid: string;
  name: string;
  email: string;
};
