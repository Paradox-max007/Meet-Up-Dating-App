import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleAuth(@Body('idToken') idToken: string) {
    return this.authService.loginWithFirebase(idToken);
  }

  @Post('email')
  @HttpCode(HttpStatus.OK)
  async emailAuth(@Body('idToken') idToken: string) {
    // Both Google and Email/Password use Firebase ID Tokens
    // So the logic is the same in our backend
    return this.authService.loginWithFirebase(idToken);
  }
}
