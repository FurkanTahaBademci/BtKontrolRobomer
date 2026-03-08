/// Robot kontrolü için komut modeli
enum RobotCommand {
  // Basit Mod (F/B/R/L/S)
  forward('F'), // İleri
  backward('B'), // Geri
  right('R'), // Sağ
  left('L'), // Sol
  stop('S'), // Dur

  // Gelişmiş Mod (A-Z) - Scratch bloklara göre
  motorAForward('A'), // Sol motor ileri, sağ motor dur
  motorABackward('C'), // Sol motor geri, sağ motor dur
  motorBForward('G'), // Sol motor dur, sağ motor ileri
  motorBBackward('I'), // Sol motor dur, sağ motor geri
  bothBackward('X'), // Her iki motor geri
  turnRightSoft('Y'), // Hafif sağa dön
  turnLeftSoft('Z'); // Hafif sola dön

  final String value;
  const RobotCommand(this.value);

  @override
  String toString() => value;
}

/// Hız komutu için özel sınıf
class SpeedCommand {
  final int speed; // 0-255 arası PWM değeri

  SpeedCommand(this.speed)
    : assert(speed >= 0 && speed <= 255, 'Hız 0-255 arasında olmalı');

  /// Arduino'ya gönderilecek format: "V{hız}\n"
  String toCommandString() => 'V$speed\n';

  @override
  String toString() => 'SpeedCommand(speed: $speed)';
}
