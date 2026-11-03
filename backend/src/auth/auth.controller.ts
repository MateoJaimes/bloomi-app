import { Body, Controller, Post, Req, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { ForgotPasswordDto, UpdatePasswordDto, LoginDto, RegisterDto } from './auth.dto';
import { AuthGuard, AuthenticatedRequest } from './auth.guard';
import { IsString, MinLength } from 'class-validator';

class RefreshDto { @IsString() @MinLength(20) refreshToken!: string; }

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register') register(@Body() dto: RegisterDto) { return this.auth.register(dto); }
  @Post('login') login(@Body() dto: LoginDto) { return this.auth.login(dto); }
  @Post('forgot-password') forgotPassword(@Body() dto: ForgotPasswordDto) { return this.auth.forgotPassword(dto.email); }

  @Post('update-password')
  @UseGuards(AuthGuard)
  updatePassword(@Req() request: AuthenticatedRequest, @Body() dto: UpdatePasswordDto) {
    return this.auth.updatePassword(request.headers.authorization!.slice(7), dto.password);
  }
  @Post('refresh') refresh(@Body() dto: RefreshDto) { return this.auth.refresh(dto.refreshToken); }

  @Post('logout')
  @UseGuards(AuthGuard)
  logout(@Req() request: AuthenticatedRequest) {
    return this.auth.logout(request.headers.authorization!.slice(7));
  }
}
