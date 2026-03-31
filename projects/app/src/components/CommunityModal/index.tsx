import React from 'react';
import { Button, ModalFooter, ModalBody } from '@chakra-ui/react';
import MyModal from '@fastgpt/web/components/common/MyModal';
import { useTranslation } from 'next-i18next';

const CommunityModal = ({ onClose }: { onClose: () => void }) => {
  const { t } = useTranslation();

  return (
    <MyModal
      isOpen={true}
      onClose={onClose}
      iconSrc="modal/concat"
      title={t('common:system.Concat us')}
    >
      <ModalBody textAlign={'center'}>联系 智算中心算力运营室 周昂果 13985240018</ModalBody>

      <ModalFooter>
        <Button variant={'whiteBase'} onClick={onClose}>
          {t('common:Close')}
        </Button>
      </ModalFooter>
    </MyModal>
  );
};

export default CommunityModal;
