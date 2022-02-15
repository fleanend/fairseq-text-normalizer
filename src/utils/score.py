import fastwer
with open('output/generate-test.txt',encoding='utf-8') as f:
  content = f.read()
  a_s = []
  b_s = []
  for line in content.split('\n'):
    if line.startswith('T-'):
      a_s.append(line[4:].replace(' ','').replace('\t',' ').replace('▁',' '))
    if line.startswith('H-'):
      piz = line[4:].split('\t')
      piz = '\t'.join([piz[0],piz[-1]])
      if piz.startswith('-'):
        piz = ''.join(piz.split('\t')[1:])
      b_s.append(piz.replace(' ','').replace('\t',' ').replace('▁',' '))

print('CER:',fastwer.score(a_s, b_s, char_level=True),'WER:', fastwer.score(a_s, b_s))