#!/usr/bin/env python3
"""Patch Chaquopy gradle plugin jar: MIN_SDK_VERSION 24 -> 21 so it accepts minSdk 23.
Usage: patch_chaquopy.py <in.jar> <out.jar>"""
import sys, struct, zipfile, shutil, os

def patch_common(data, newval=21):
    d=bytearray(data)
    assert d[:4]==b'\xca\xfe\xba\xbe'
    i=8; cpc=struct.unpack_from('>H',d,i)[0]; i+=2
    cp=[None]*cpc; intpos={}
    k=1
    while k<cpc:
        tag=d[i]; i+=1
        if tag==1:
            ln=struct.unpack_from('>H',d,i)[0]; i+=2
            cp[k]=(1,bytes(d[i:i+ln]).decode('utf-8','ignore')); i+=ln
        elif tag==3:
            intpos[k]=i; cp[k]=(3,struct.unpack_from('>i',d,i)[0]); i+=4
        elif tag==4: cp[k]=(4,None); i+=4
        elif tag==5: cp[k]=(5,None); i+=8; k+=1
        elif tag==6: cp[k]=(6,None); i+=8; k+=1
        elif tag in (7,8,16,19,20): cp[k]=(tag,struct.unpack_from('>H',d,i)[0]); i+=2
        elif tag in (9,10,11,12,17,18): cp[k]=(tag,None); i+=4
        elif tag==15: cp[k]=(15,None); i+=3
        else: raise SystemExit(f'unknown tag {tag}')
        k+=1
    utf=[idx for idx,v in enumerate(cp) if v and v[0]==1 and v[1]=='MIN_SDK_VERSION']
    if not utf: raise SystemExit('MIN_SDK_VERSION utf8 not found')
    i2=i+6
    ic=struct.unpack_from('>H',d,i2)[0]; i2+=2+2*ic
    fc=struct.unpack_from('>H',d,i2)[0]; i2+=2
    patched=False
    for _ in range(fc):
        acc,name_i,desc_i,ac=struct.unpack_from('>HHHH',d,i2); i2+=8
        for _a in range(ac):
            an_i,alen=struct.unpack_from('>HI',d,i2); i2+=6
            if cp[name_i] and cp[name_i][1]=='MIN_SDK_VERSION' and cp[an_i] and cp[an_i][1]=='ConstantValue':
                cv=struct.unpack_from('>H',d,i2)[0]
                assert cp[cv][0]==3
                off=intpos[cv]
                old=struct.unpack_from('>i',d,off)[0]
                struct.pack_into('>i',d,off,newval)
                print(f'MIN_SDK_VERSION {old} -> {newval} at offset {off}')
                patched=True
            i2+=alen
    if not patched: raise SystemExit('ConstantValue not patched')
    return bytes(d)

def main():
    src,dst=sys.argv[1],sys.argv[2]
    zin=zipfile.ZipFile(src); 
    tmp=dst+'.tmp'
    zout=zipfile.ZipFile(tmp,'w',zipfile.ZIP_DEFLATED)
    target='com/chaquo/python/internal/Common.class'
    for item in zin.infolist():
        data=zin.read(item.filename)
        if item.filename==target:
            data=patch_common(data)
        zout.writestr(item, data)
    zout.close(); zin.close()
    shutil.move(tmp,dst)
    print('wrote',dst)

if __name__=='__main__':
    main()
