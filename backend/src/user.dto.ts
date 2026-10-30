import { Type } from 'class-transformer';
import { Allow, IsArray, IsDateString, IsEnum, IsInt, IsOptional, IsString, IsUUID, Length, Max, MaxLength, Min, ValidateNested } from 'class-validator';

export enum ApiBloodType { OMinus = 'O-', OPlus = 'O+', AMinus = 'A-', APlus = 'A+', BMinus = 'B-', BPlus = 'B+', ABMinus = 'AB-', ABPlus = 'AB+' }

export class UpdateProfileDto {
  @IsOptional() @IsString() @Length(1, 100) firstName?: string;
  @IsOptional() @IsString() @Length(1, 100) secondName?: string;
  @IsOptional() @IsString() @Length(1, 100) lastName?: string;
  @IsOptional() @IsString() @Length(1, 100) secondLastName?: string;
  @IsOptional() @IsString() @Length(7, 25) phone?: string;
  @IsOptional() @IsDateString() birthDate?: string;
  @IsOptional() @IsEnum(ApiBloodType) bloodType?: ApiBloodType;
  @IsOptional() @IsString() @MaxLength(80) gender?: string;
  @IsOptional() @IsString() @MaxLength(250) address?: string;
  @IsOptional() @IsString() @MaxLength(100) city?: string;
  @IsOptional() @IsString() @MaxLength(100) department?: string;
}

export class UpdateMedicalProfileDto {
  @IsOptional() @IsString() @MaxLength(4000) medications?: string;
  @IsOptional() @IsString() @MaxLength(4000) conditions?: string;
  @IsOptional() @IsString() @MaxLength(4000) allergies?: string;
}

export class AnswerDto {
  @IsUUID() questionId!: string;
  @Allow()
  answer!: unknown;
}

export class SubmitQuestionnaireDto {
  @IsUUID() versionId!: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => AnswerDto) answers!: AnswerDto[];
}

export class RedeemRewardDto {
  @IsUUID() rewardId!: string;
  @IsOptional() @IsInt() @Min(1) @Max(10) quantity?: number;
}
