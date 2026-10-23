/// wa.me attend un numéro international sans signe +.
/// Les numéros français à dix chiffres sont convertis avec l'indicatif 33.
String whatsappNumber(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  } else if (digits.length == 10 && digits.startsWith('0')) {
    digits = '33${digits.substring(1)}';
  }
  return digits;
}
