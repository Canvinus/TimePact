import {
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalCloseButton,
  ModalBody,
  Heading,
  Stack,
  Text,
  ModalFooter,
  Button,
} from '@chakra-ui/react'

export default function PactModal({ clicked, tokenId, info, handleClose }) {
  return (
    <Modal isOpen={clicked} onClose={handleClose}>
      <ModalOverlay />
      <ModalContent>
        <ModalHeader>Pact #{tokenId}</ModalHeader>
        <ModalCloseButton />
        <ModalBody>
          <Heading fontSize={'2xl'} fontFamily={'body'} fontWeight={500}>
            {clicked && info && info[0].toString()}
          </Heading>
          <Stack direction={'row'} align={'center'}>
            <Text fontWeight={800} fontSize={'xl'}>
              {clicked && info && info[2].toString()}
            </Text>
          </Stack>
        </ModalBody>
        <ModalFooter>
          <Button colorScheme="blue" mr={3} onClick={handleClose}>
            Close
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}
