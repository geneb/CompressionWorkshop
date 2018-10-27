;********* UPCKFLSV.INC - variables for CWUnpackFiles & CWUnpackFilesD
;
;Copyright (c) 1992 Fred Sexton Jr.

s_hand       TEXTEQU <WORD PTR ds:[55944]>
d_hand       TEXTEQU <WORD PTR ds:[55946]>
dpath_end    TEXTEQU <WORD PTR ds:[55948]>

fs_mode      TEXTEQU <WORD PTR ds:[55950]>
cmpr_len     TEXTEQU <WORD PTR ds:[55952]>
name_len     TEXTEQU <WORD PTR ds:[55954]>
cmp_ind      TEXTEQU <WORD PTR ds:[55956]>
fnd_ind      TEXTEQU <WORD PTR ds:[55958]>

stor_done    TEXTEQU <WORD PTR ds:[55960]>
t_loc        TEXTEQU <WORD PTR ds:[55962]>
i_buff_count TEXTEQU <WORD PTR ds:[55964]>
i_buff_ptr   TEXTEQU <WORD PTR ds:[55966]>
o_buff_ptr   TEXTEQU <WORD PTR ds:[55968]>

o_stk_count  TEXTEQU <WORD PTR ds:[55970]>
o_stk_ptr    TEXTEQU <WORD PTR ds:[55972]>
nxt_hdrl     TEXTEQU <WORD PTR ds:[55974]>
nxt_hdrh     TEXTEQU <WORD PTR ds:[55976]>
f_time       TEXTEQU <WORD PTR ds:[55978]>

f_date       TEXTEQU <WORD PTR ds:[55980]>
fsize_l      TEXTEQU <WORD PTR ds:[55982]>
fsize_h      TEXTEQU <WORD PTR ds:[55984]>

suf_loc      TEXTEQU <16384>
o_stk_loc    TEXTEQU <24576>
dest_loc     TEXTEQU <40960>
cmpr_loc     TEXTEQU <41027>
o_buff_loc   TEXTEQU <41039>
o_buff_max   TEXTEQU <47727>
hdr_buff_loc TEXTEQU <55974>
fname_loc    TEXTEQU <55986>
vari_loc     TEXTEQU <55920>
