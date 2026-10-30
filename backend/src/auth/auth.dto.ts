import { IsEmail, IsEnum, IsString, Length, MinLength, MaxLength } from 'class-validator';

export enum ApiDocumentType { cc = 'cc', ce = 'ce', passport = 'passport', other = 'other' }

export class RegisterDto {
  @IsEmail() @MaxLength(254) email!: string;
  @IsString() @MinLength(10) @MaxLength(128) password!: string;
  @IsEnum(ApiDocumentType) documentType!: ApiDocumentType;
  @IsString() @Length(5, 30) documentNumber!: string;
}

export class LoginDto {
  @IsEmail() @MaxLength(254) email!: string;
  @IsString() @MinLength(1) @MaxLength(128) password!: string;
}
