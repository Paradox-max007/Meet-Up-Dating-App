import { Controller, Post, Body, UseGuards, Request, HttpStatus, HttpCode, Get } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('profile')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Request() req: any, @Body() profileData: any) {
    const userId = req.user.id;
    return this.usersService.update(userId, profileData);
  }

  @Get('discover')
  @UseGuards(JwtAuthGuard)
  async getDiscoverable(@Request() req: any) {
    const userId = req.user.id;
    return this.usersService.findDiscoverable(userId);
  }
}
