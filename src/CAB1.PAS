(* file = cab1.pas
 *
 * cab1.exe : �J�x�\���R���p�C��
 *
 * ���X�g�A�b�v�f�[�g�@'90/08/16  �I�P�Q���^���c�W
 *
 * Copyright (C) 1990, 91 Ockeghem
 *)

program cab1;
uses cbinit, cbmodule, cbflush;

(* �|�|�|�|�|�|�|�|�|�|�|�|�|�|�@�֐���`�@�|�|�|�|�|�|�|�|�|�|�|�|�| *)

(*  �ړI�F�R���p�C���̃��C���v���O����
 *
 *  �߂�l�F����I���i�G���[�O�j�̏ꍇ�͂O��Ԃ��B
 *)
begin
	Init;
	programOrUnit;
	Flush;
	halt(0)
end.
