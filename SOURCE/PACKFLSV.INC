;********** PACKFLSV.INC - variables for CWPackFiles,CWPackFilesD,CWUpdate
;
;Copyright (c) 1992 Fred Sexton Jr.

d_hand       TEXTEQU  <WORD PTR ds:[55920]>
s_hand       TEXTEQU  <WORD PTR ds:[55922]>
prev_hdrl    TEXTEQU  <WORD PTR ds:[55924]>
prev_hdrh    TEXTEQU  <WORD PTR ds:[55926]>
this_hdrl    TEXTEQU  <WORD PTR ds:[55928]>

this_hdrh    TEXTEQU  <WORD PTR ds:[55930]>
orig_dta_ofs TEXTEQU  <WORD PTR ds:[55932]>
orig_dta_seg TEXTEQU  <WORD PTR ds:[55934]>
max_outl     TEXTEQU  <WORD PTR ds:[55936]>
max_outh     TEXTEQU  <WORD PTR ds:[55938]>

fsize_decl   TEXTEQU  <WORD PTR ds:[55940]>
fsize_dech   TEXTEQU  <WORD PTR ds:[55942]>
hdr_len      TEXTEQU  <WORD PTR ds:[55944]>
spec_end     TEXTEQU  <WORD PTR ds:[55946]>
dest_end     TEXTEQU  <WORD PTR ds:[55948]>

name_len     TEXTEQU  <WORD PTR ds:[55950]>
f_opened     TEXTEQU  <WORD PTR ds:[55952]>
i_buff_count TEXTEQU  <WORD PTR ds:[55954]>
i_buff_ptr   TEXTEQU  <WORD PTR ds:[55956]>
o_buff_ptr   TEXTEQU  <WORD PTR ds:[55958]>

hold_val     TEXTEQU  <WORD PTR ds:[55960]>
t_loc        TEXTEQU  <WORD PTR ds:[55962]>
in_val       TEXTEQU  <BYTE PTR ds:[55964]>
total_l      TEXTEQU  <WORD PTR ds:[55966]>
total_h      TEXTEQU  <WORD PTR ds:[55968]>

tyme_int     TEXTEQU  <WORD PTR ds:[55970]>
dyte_int     TEXTEQU  <WORD PTR ds:[55972]>
cg_hand      TEXTEQU  <WORD PTR ds:[55974]>
cg_hdrl      TEXTEQU  <WORD PTR ds:[55976]>
cg_hdrh      TEXTEQU  <WORD PTR ds:[55978]>

nxt_cg_hdrl  TEXTEQU  <WORD PTR ds:[55980]>
nxt_cg_hdrh  TEXTEQU  <WORD PTR ds:[55982]>
cg_cont_flag TEXTEQU  <WORD PTR ds:[55984]>
cg_totwl     TEXTEQU  <WORD PTR ds:[55986]>
cg_totwh     TEXTEQU  <WORD PTR ds:[55988]>

cg_maxxl     TEXTEQU  <WORD PTR ds:[55990]>
cg_maxxh     TEXTEQU  <WORD PTR ds:[55992]>
tmp_var1     TEXTEQU  <WORD PTR ds:[55994]>
tmp_var2     TEXTEQU  <WORD PTR ds:[55996]>
tmp_var3     TEXTEQU  <WORD PTR ds:[55998]>

dta_loc      TEXTEQU  <45145>
o_buff_loc   TEXTEQU  <45273>
i_buff_loc   TEXTEQU  <45785>
dest_copy    TEXTEQU  <55785>
spec_copy    TEXTEQU  <55852>
vari_loc     TEXTEQU  <55920>
tmpv_loc     TEXTEQU  <55994>
thdr_loc     TEXTEQU  <55928>
tyme_loc     TEXTEQU  <55970>
dyte_loc     TEXTEQU  <55972>
