export function isEmailValid(email: string): boolean {
  const pattern = [
    "^(",
    // Parte antes do @ (usuário)
    // - Aceita caracteres comuns de email
    // - Permite pontos (ex: nome.sobrenome)
    "([^<>()[\\]\\\\.,;:\\s@']+(\\.[^<>()[\\]\\\\.,;:\\s@']+)*)",

    // Separador obrigatório do email
    ")@(",

    // Domínio como IP (ex: [192.168.0.1])
    "(\\[[0-9]{1,3}(\\.[0-9]{1,3}){3}\\])",

    // OU domínio padrão (ex: gmail.com, empresa.com.br)
    // - letras, números e hífen
    // - seguido de ponto + TLD (ex: .com, .org)
    "|(([a-zA-Z\\-0-9]+\\.)+[a-zA-Z]{2,})",

    // Fim do domínio
    ")$",
  ].join("");

  return new RegExp(pattern).test(email.toLowerCase());
}
