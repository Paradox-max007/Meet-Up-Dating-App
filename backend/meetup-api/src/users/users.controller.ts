import { Controller, Post, Body, UseGuards, Request, HttpStatus, HttpCode } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('profile')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Request() req: any, @Body() profileData: any) {
    // In production, user data comes from the verified JWT in req.user
    const userId = req.user.id;
    return this.usersService.update(userId, profileData);
  }
}
